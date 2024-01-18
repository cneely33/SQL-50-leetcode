/****** Select ******/
-- Recyclable and Low Fat Products
/*
SELECT
product_id
FROM Products
WHERE low_fats = 'Y'
AND recyclable = 'Y'
;

----------------------------------------------------------------------------------------------------------------------
-- Find Customer Referee
SELECT
"name"
FROM Customer
WHERE referee_id != 2 or referee_id IS NULL

----------------------------------------------------------------------------------------------------------------------
--Big Countries
SELECT
name, population, area
FROM World
WHERE area >= 3000000
OR population >= 25000000
;
----------------------------------------------------------------------------------------------------------------------
-- Article Views I
SELECT DISTINCT
author_id as id
FROM Views
WHERE author_id = viewer_id
ORDER BY author_id
----------------------------------------------------------------------------------------------------------------------
-- Invalid Tweets
SELECT
tweet_id
FROM Tweets
WHERE LENGTH(content) > 15
*/
----------------------------------------------------------------------------------------------------------------------
/****** Basic Joins ******/
----------------------------------------------------------------------------------------------------------------------
-- Replace Employee ID With The Unique Identifier
SELECT
    eu.unique_id,
    e."name"
FROM Employees as e

LEFT JOIN EmployeeUNI as eu
ON e.id = eu.id
;
----------------------------------------------------------------------------------------------------------------------
--Product Sales Analysis I
SELECT
    product_name,
    year,
    price
FROM Sales as s
INNER JOIN Product as p
ON s.product_id = p.product_id
----------------------------------------------------------------------------------------------------------------------
--Customer Who Visited but Did Not Make Any Transactions
SELECT
    customer_id,
    COUNT(1) as count_no_trans
FROM Transactions
RIGHT JOIN Visits
    ON Transactions.visit_id = Visits.visit_id
WHERE transaction_id IS NULL
GROUP BY customer_id
;
----------------------------------------------------------------------------------------------------------------------
-- Rising Temperature
SELECT
    w1.Id
FROM Weather w1, weather w2
WHERE w1.recordDate - 1 = w2.recordDate
AND w1.temperature > w2.temperature
;
----------------------------------------------------------------------------------------------------------------------
-- Average Time of Process per Machine
SELECT
act_start.machine_id,
ROUND(
    (AVG((act_end.timestamp - act_start.timestamp))::numeric)
    , 3) as processing_time
FROM (
         SELECT
            machine_id,
            process_id,
            timestamp
         FROM Activity
         WHERE activity_type = 'start'
     ) as act_start
INNER JOIN (
         SELECT
            machine_id,
            process_id,
            timestamp
         FROM Activity
         WHERE activity_type = 'end'
     ) as act_end
on act_start.machine_id = act_end.machine_id
AND  act_start.process_id = act_end.process_id
GROUP BY act_start.machine_id
;

-- option 2
SELECT
   a1.machine_id,
    ROUND(
        AVG(a1.timestamp-a2.timestamp)::numeric
        ,3) as processing_time
FROM Activity a1
INNER JOIN Activity a2
    ON a1.machine_id=a2.machine_id
WHERE a1.activity_type='end'
  AND a2.activity_type='start'
GROUP BY a1.machine_id;

--- clever
SELECT
    machine_id,
    ROUND(CAST(AVG(duration) AS numeric), 3) AS processing_time
FROM (
    SELECT
        machine_id,
        process_id,
           -- take advantage of timestamp being long instead of wide
        SUM(case when activity_type = 'start' then -timestamp else timestamp end) AS duration
    FROM
        Activity
    GROUP BY
        machine_id,
        process_id
) as case_neg_sum
GROUP BY
    machine_id
ORDER BY
    machine_id;
----------------------------------------------------------------------------------------------------------------------
-- Employee Bonus
SELECT
name,
bonus
FROM Employee as e
LEFT JOIN Bonus as b
ON e.empId = b.empId
WHERE bonus < 1000
OR bonus IS NULL
;
----------------------------------------------------------------------------------------------------------------------
-- Students and Examinations
SELECT DISTINCT
    s.student_id,
    student_name,
    sub.subject_name,
    COALESCE(attended_exams , 0) as attended_exams
FROM Students as s

CROSS JOIN Subjects as sub

LEFT JOIN (SELECT
            student_id, subject_name, COUNT(subject_name) as attended_exams
            FROM Examinations GROUP BY student_id, subject_name) as e
    ON s.student_id = e.student_id
    AND sub.subject_name = e.subject_name

ORDER BY s.student_id, sub.subject_name
;
----------------------------------------------------------------------------------------------------------------------
-- Managers with at Least 5 Direct Reports (medium)
SELECT
    name
FROM Employee as ee
INNER JOIN (
    SELECT
        managerId,
        COUNT(*) as count_reports
    FROM Employee
    GROUP BY managerId
    ) as reportCounts
on ee.id = reportCounts.managerId
WHERE count_reports >= 5
;
-- option 2
SELECT
       e1.name
FROM Employee e1
JOIN  Employee e2
    on e1.id = e2.managerId
GROUP BY e1.name, e2.managerId
HAVING COUNT(1) >= 5;

-- clever solution
select name from employee
where id = any (select distinct
                        managerid
                from employee
                group by (managerid)
                having count(*) >= 5);

----------------------------------------------------------------------------------------------------------------------
-- Confirmation Rate (medium)
SELECT
Signups.user_id,
ROUND(
    COALESCE(
        (AVG(CASE WHEN "action" = 'confirmed' THEN 1 ELSE 0 END)::decimal)
    , 0)
,2)

 AS confirmation_rate
FROM Signups
LEFT JOIN Confirmations
ON Signups.user_id = Confirmations.user_id
GROUP BY Signups.user_id
----------------------------------------------------------------------------------------------------------------------
/***** Basic Aggregate Functions *****/
----------------------------------------------------------------------------------------------------------------------
-- Not Boring Movies
SELECT
    id,
    movie,
    description,
    rating
FROM Cinema
WHERE description != 'boring'
AND (id % 2) != 0
ORDER BY rating DESC
;
----------------------------------------------------------------------------------------------------------------------
-- Average Selling Price
SELECT
    prices.product_id,
    COALESCE(
        ROUND(
            (SUM(price * units)::float/SUM(units)
                )::numeric
            , 2),0) as average_price
FROm prices
LEFT JOIN UnitsSold
ON purchase_date BETWEEN start_date and end_date
AND UnitsSold.product_id = Prices.product_id
GROUP BY prices.product_id;
----------------------------------------------------------------------------------------------------------------------
-- Project Employees I
SELECT
project_id,
    ROUND(
        AVG(experience_years)::numeric
        , 2) as average_years
FROM Project as p
INNER JOIN Employee as e
on p.employee_id = e.employee_id
GROUP BY project_id
;

----------------------------------------------------------------------------------------------------------------------
-- Percentage of Users Attended a Contest
SELECT
contest_id,
       ROUND(
           -- registered users
                COUNT( user_id)::numeric /
            -- total users
                (SELECT COUNT( user_id) FROM Users) * 100
           , 2) as percentage
FROM Register
GROUP BY contest_id
ORDER BY percentage DESC, contest_id ASC
;
----------------------------------------------------------------------------------------------------------------------
-- Queries Quality and Percentage
SELECT
query_name,
-- quality
ROUND(AVG(rating::numeric/position)
    , 2) as quality,
-- poor
ROUND(
    (SUM(CASE WHEN rating < 3 THEN 1 ELSE 0 END)::numeric / COUNT(*)) * 100
    , 2) as poor_query_percentage
FROM Queries
WHERE query_name IS NOT NULL
GROUP BY query_name
;
----------------------------------------------------------------------------------------------------------------------
-- Monthly Transactions I (medium)
SELECT
    to_char(trans_date, 'YYYY-MM') as month,
    country,
    -- number of transactions
    COUNT(*) as trans_count ,
    -- number of approved transactions
    SUM(CASE WHEN state = 'approved' THEN 1 ELSE 0 END) as approved_count ,
    -- total amount for all transactions
    SUM(amount) as trans_total_amount ,
    -- total amount for approved transactions
    SUM(CASE WHEN state = 'approved' THEN amount ELSE 0 END) AS approved_total_amount
FROM Transactions
GROUP BY month, country
----------------------------------------------------------------------------------------------------------------------
--  Immediate Food Delivery II (medium)
with
    all_first_orders as (
        SELECT
            Customer_id,
            MIN(order_date) as first_order_date
        FROM Delivery
        GROUP BY Customer_id
    )
SELECT
    ROUND(
        -- immediate first order count
        SUM(CASE WHEN order_date = customer_pref_delivery_date THEN 1 ELSE 0 END)::numeric
    -- total first order count
        /COUNT(*) * 100
        , 2)
as immediate_percentage

FROM Delivery

INNER JOIN all_first_orders
    ON Delivery.Customer_id = all_first_orders.Customer_id
    AND order_date = first_order_date
;

-- option 2
SELECT
    ROUND(
        AVG(
            CASE
                WHEN order_date = customer_pref_delivery_date THEN 1
                ELSE 0
            END
        ) * 100
    , 2) AS immediate_percentage
FROM Delivery
WHERE
    (customer_id, order_date) IN
    (
        SELECT
            customer_id,
            MIN(order_date)
        FROM Delivery
        GROUP BY customer_id
    );
----------------------------------------------------------------------------------------------------------------------
--  Game Play Analysis IV (medium)

with total_users as (
    SELECT
        COUNT(DISTINCT player_id) as players
    FROM Activity
),
     consecutive_logins as (
        SELECT
            COUNT(DISTINCT player_id) as consecutive_players
        FROM
         (
         -- first logins
         SELECT
            player_id,
            event_date,
            LAG(event_date, 1) over w as previous_login,
            row_number() over w as row_num
         FROM Activity
             WINDOW w as (partition by player_id ORDER BY event_date ASC)
         ) as logins
         WHERE row_num = 2
         AND (event_date - previous_login) = 1
     )
SELECT
        --- get count with logins on consecutive days
ROUND(consecutive_players::numeric
        -- get count of total users
        / players, 2) as fraction
FROM total_users, consecutive_logins
;

-- option 2
SELECT
       ROUND(
           SUM(CASE
                WHEN a1.event_date = a2.first_login_date + 1 THEN 1
                ELSE 0
                END)
             /CAST(
                 COUNT(DISTINCT a1.player_id)
                 AS decimal)
    , 2) as fraction
FROM Activity AS a1
    CROSS JOIN (SELECT player_id,
                       MIN(event_date) AS first_login_date
                FROM Activity
                    GROUP BY player_id) as a2
WHERE a1.player_id = a2.player_id;

-- option 3
with consecutive_after as (
     select player_id, event_date, lead(event_date) over (partition by player_id order by event_date) as next_date, ROW_NUMBER() over(partition by player_id order by event_date) row_number from activity),
player_amount as (select count(distinct player_id) as player_amount from activity),
consecutive_amount as (select count(1) as current_amount from consecutive_after where next_date is not null and next_date-event_date = 1 and row_number = 1)
select ROUND(CAST(current_amount as numeric) / player_amount,2) as fraction from consecutive_amount, player_amount;

----------------------------------------------------------------------------------------------------------------------
/****** Sorting and Grouping ******/
----------------------------------------------------------------------------------------------------------------------
-- Number of Unique Subjects Taught by Each Teacher
SELECT
    teacher_id,
    COUNT(DISTINCT subject_id) as cnt
FROM Teacher
GROUP BY teacher_id;
----------------------------------------------------------------------------------------------------------------------
-- User Activity for the Past 30 Days I
SELECT
    activity_date as day,
    COUNT(DISTINCT user_id) as active_users
FROM Activity
WHERE activity_date BETWEEN '2019-07-27'::date -29 AND '2019-07-27'
GROUP BY activity_date;
----------------------------------------------------------------------------------------------------------------------
-- Product Sales Analysis III (medium)
with
    product_first_sale_year as (
                            SELECT
                                product_id,
                                MIN(year) as product_first_year
                            FROM Sales
                            GROUP BY product_id
    )
SELECT
    sales.product_id,
    year as first_year,
    quantity,
    price
FROM Sales
INNER JOIN product_first_sale_year
    ON sales.product_id = product_first_sale_year.product_id
    AND sales.year = product_first_sale_year.product_first_year
;

-- option 2
with stg as (
    select
        product_id,
        year,
        quantity,
        price,
        rank() over(partition by product_id order by year) as rn
    from Sales
)
select
    product_id,
    year as first_year,
    quantity,
    price
from stg
where rn = 1
;
----------------------------------------------------------------------------------------------------------------------
-- Classes More Than 5 Students
SELECT
    class
FROM Courses
GROUP BY class
HAVING COUNT(student) > 4;
----------------------------------------------------------------------------------------------------------------------
-- Find Followers Count
SELECT
    user_id,
    COUNT(follower_id) as followers_count
FROM Followers
GROUP BY user_id
ORDER BY user_id
;
----------------------------------------------------------------------------------------------------------------------
-- Biggest Single Number
WITH count_nums as(
    SELECT
        num,
        COUNT(*) as num_count
    FROM MyNumbers
    GROUP BY num)
SELECT
num
FROM count_nums
RIGHT JOIN (SELECT
                MAX(num) as max_num
            FROM count_nums
            WHERE num_count = 1) as max_numtb
ON num = max_num
;
-- option 2
SELECT
    MAX(NUM) AS NUM
FROM(
    SELECT
        NUM
    FROM MYNUMBERS
    GROUP BY NUM
    HAVING COUNT(NUM)=1
)  as max_numtb;
----------------------------------------------------------------------------------------------------------------------
-- Customers Who Bought All Products (medium)
SELECT
customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (SELECT COUNT(product_key) FROM Product)
;
----------------------------------------------------------------------------------------------------------------------
/****** Advanced Selects and Joins ******/
----------------------------------------------------------------------------------------------------------------------
-- The Number of Employees Which Report to Each Employee
-- Write your PostgreSQL query statement below
with direct_repot_stats as (
--- Get the ids of managers
-- count the number of reports and avg age of reports
                SELECT
                    reports_to,
                       COUNT(*) as reports_count ,
                       AVG(age) as average_age
                FROM Employees
                    GROUP BY reports_to
                )
SELECT
    employee_id,
    name,
    reports_count,
    Round(average_age) as average_age
FROM Employees
INNER JOIN direct_repot_stats
    ON Employees.employee_id = direct_repot_stats.reports_to
ORDER BY employee_id
;

----------------------------------------------------------------------------------------------------------------------
--Triangle Judgement
SELECT
x,
y,
z,
CASE
WHEN x + y > z AND x + z > y AND z + y > x THEN 'Yes'
ELSE 'No' END as triangle
FROM Triangle
;
----------------------------------------------------------------------------------------------------------------------
-- Consecutive Numbers
SELECT DISTINCT
num as ConsecutiveNums
FROM (SELECT
        num,
        LAG(num, 1) OVER (order by id) as lag_num,
        LEAD(num, 1) OVER (order by id) as lead_num
    FROM Logs
) lags_and_leads
WHERE num = lag_num
AND num = lead_num
;
----------------------------------------------------------------------------------------------------------------------
-- Product Price at a Given Date (Medium)
with changed_prior_to_cut as (
    SELECT product_id,
           new_price
    FROM Products
    WHERE (product_id, change_date) IN (SELECT product_id,
                                               MAX(change_date)
                                        FROM Products
                                        WHERE change_date <= '2019-08-16'
                                        GROUP BY product_id)
    ),
all_products as (
    SELECT DISTINCT
         product_id
    FROM Products
    )
SELECT
    ap.product_id,
    COALESCE(new_price, 10) as price
-- All products as center table to impute static price for items not in changed_prior_to_cut
FROM all_products as ap
LEFT JOIN changed_prior_to_cut as np
ON ap.product_id = np.product_id
;

-- option 2
select
       p2.product_id,
       coalesce(price,10) as price
FROM (select distinct
                product_id
            from Products) as p2
LEFT join (
    select distinct
        product_id,
        first_value(new_price) over (partition by product_id order by change_date DESC) as price
    from Products
    where change_date <='2019-08-16') as p1
on p1.product_id = p2.product_id;
----------------------------------------------------------------------------------------------------------------------
--Last Person to Fit in the Bus (Medium)
with queue_list as (
         SELECT person_id,
                person_name,
                weight,
                turn,
                SUM(weight) OVER (ORDER BY turn) as running_weight
         FROM Queue
     )
SELECT
    person_name
FROM queue_list
WHERE turn = (SELECT MAX(turn) FROM queue_list WHERE running_weight <= 1000)
;
----------------------------------------------------------------------------------------------------------------------
-- Count Salary Categories (Medium)
-- split "case whens" to ensure all categories are created
select
   'Low Salary' as category,
   sum(case when income<20000 then 1 else 0 end)  as accounts_count
from accounts
union
select
   'Average Salary' ,
   sum(case when income BETWEEN 20000 AND 50000 then 1 else 0 end)
from accounts
union
select
   'High Salary',
   sum(case when income > 50000 then 1 else 0 end)
from accounts
;

----------------------------------------------------------------------------------------------------------------------
/****** Subqueries ******/
----------------------------------------------------------------------------------------------------------------------
-- Employees Whose Manager Left the Company
SELECT
    employee_id
FROM Employees
WHERE salary < 30000
AND manager_id NOT IN (SELECT employee_id FROM Employees)
ORDER BY employee_id
;
----------------------------------------------------------------------------------------------------------------------
-- Exchange Seats (Medium)
with evens as (
    SELECT
        id,
        student,
        row_number() over () as row_num
    FROM seat
    WHERE id % 2 = 0
),
     odds as (
     SELECT
        id,
        student,
        row_number() over () as row_num
    FROM seat
    WHERE id % 2 = 1
     ),
swap_seats_odd as (
    SELECT
        COALESCE(evens.id, odds.id) as id,
           odds.student
    FROm odds
    LEFT JOIN evens
    on odds.row_num = evens.row_num
),
swap_seats_even as (
SELECT
        COALESCE(odds.id, evens.id) as id,
           evens.student
    FROm evens
    LEFT JOIN odds
    on evens.row_num = odds.row_num
)
SELECT
id, student
FROM swap_seats_odd
UNION ALL
SELECT
id, student
FROM swap_seats_even
ORDER BY id
;

-- option 2
SELECT
    (
        CASE
            WHEN id % 2 = 0 THEN id - 1
            WHEN id = (SELECT COUNT(*) FROM Seat) AND id % 2 = 1 THEN id
            ELSE id + 1
        END
    ) AS id,
    student
FROM
    Seat
ORDER BY
    id



----------------------------------------------------------------------------------------------------------------------
-- Movie Rating (Medium)
SELECT
    results
FROM (
SELECT
     name as results
FROM (SELECT user_id,
               count(1)              as ratings,
               MAX(COUNT(1)) OVER () as max_ratings
        FROM movierating
        GROUP BY user_id
       ) as most_active
INNER JOIN users
ON Users.user_id = most_active.user_id
WHERE ratings = max_ratings
ORDER BY name
limit 1
    ) as highest_users
UNION ALL
SELECT
results
FROM (
         SELECT
                title as results
         FROM (
                  SELECT movie_id,
                         AVG(rating)              as rating,
                         MAX(AVG(rating)) OVER () as highest_rating
                  FROM movierating
                  WHERE
                    created_at >= '2020-02-01'
                    AND created_at < '2020-03-01'
                  GROUP BY movie_id
              ) as higest_avg
                  INNER JOIN Movies
                             ON Movies.movie_id = higest_avg.movie_id
         WHERE rating = highest_rating
         ORDER BY title
         LIMIT 1
     ) as highest_title
;

-- Option 2
(select
        Users.name as results
from Users
INNER join MovieRating
    on Users.user_id = MovieRating.user_id

group by Users.user_id, Users.name
order by count(Users.user_id) desc, Users.name asc
limit 1)
union all
(select
        Movies.title as results
from Movies
INNER join MovieRating
    on Movies.movie_id = MovieRating.movie_id

where MovieRating.created_at between '2020-02-01' and '2020-02-29'
group by Movies.movie_id, Movies.title
order by avg(MovieRating.rating) desc, Movies.title asc
limit 1);

----------------------------------------------------------------------------------------------------------------------
-- Restaurant Growth (Medium)
WITH daily_sum as (SELECT
                      visited_on,
                      SUM(amount) as amount
               FROM Customer
               GROUP BY 1
              )
--  rolling_avg as (
         SELECT
                visited_on,
                SUM(amount) OVER w as amount,
                ROUND(AVG(amount) OVER w,
                      2) as average_amount
         FROM daily_sum
     WINDOW w as (order by visited_on range between '6 days' preceding and current row)
--      )
SELECT
visited_on,
amount,
average_amount
FROM rolling_avg
WHERE visited_on >= (SELECT MIN(visited_on) + 6 FROM Customer)
;

/* if date range need to be imputed */
-- generate date range table
-- SELECT
--        ordinality,
--        day,
--        date_part('week', day) AS week
--     FROM    generate_series('2020-01-02', '2020-01-15', '1 day'::interval)
-- WITH ORDINALITY AS day;

-- option 2
SELECT A.visited_on,
       SUM(B.amount) AS amount,
       -- requirement was hard 7 days
       ROUND(SUM(B.amount)::numeric / 7, 2) AS average_amount
FROM (SELECT DISTINCT
                      visited_on
    FROM Customer
    WHERE visited_on - 6 IN
          (SELECT visited_on FROM Customer)) AS A,
Customer B
WHERE A.visited_on BETWEEN B.visited_on
                        AND B.visited_on + 6
GROUP BY A.visited_on ORDER BY visited_on ASC
;
----------------------------------------------------------------------------------------------------------------------
-- Friend Requests II: Who Has the Most Friends (Medium)
WITH all_ids as (
        SELECT
            requester_id as id
        FROM RequestAccepted
        UNION ALL
        SELECT
            accepter_id as id
        FROM RequestAccepted
    ),
all_id_counts as (
    SELECT
        id,
        COUNT(*) as friend_count
    FROM all_ids
    GROUP BY id
)
SELECT
       id ,
    (SELECT DISTINCT
    COUNT(id) OVER () as id
    FROM all_ids
        WHERE all_ids.id = all_id_counts.id) as num
FROM all_id_counts
WHERE friend_count = (SELECT MAX(friend_count) FROM all_id_counts)

-- option 2
select
       id,
       sum(cnt) num
from(
    (select
        requester_id as id,
        count(accepter_id) as cnt
    from requestaccepted
    group by 1)
union all
    (select
       accepter_id as id,
       count(requester_id) as cnt
    from requestaccepted
    group by 1)
) as freind
group by 1
order by sum(cnt) desc
limit 1
----------------------------------------------------------------------------------------------------------------------
-- Investments in 2016 (Medium)
with policyholder_2015_value_counts as (
    SELECT
        tiv_2015
    FROM Insurance
    GROUP BY tiv_2015
    HAVING COUNT(tiv_2015) > 1
),
lat_long_pairs as (
    SELECT
    lat, lon
    FROM Insurance
    GROUP BY lat, lon
    HAVING COUNT(*) = 1
)
SELECT
ROUND(SUM(tiv_2016)::numeric,2) as tiv_2016
FROM Insurance
WHERE tiv_2015 IN (SELECT tiv_2015 from policyholder_2015_value_counts)
and (lat, lon) IN (SELECT lat, lon FROM lat_long_pairs)
;
----------------------------------------------------------------------------------------------------------------------
-- Department Top Three Salaries (Hard)
with top_salaries_by_dept as (
    SELECT DISTINCT
        departmentId,
        salary,
        DENSE_RANK() OVER (partition by departmentID order by salary DESC) as salary_rank
    FROM employee
)
SELECT
    Department."name" as Department,
    Employee."name" as Employee,
    Employee.Salary
FROM Employee

INNER JOIN Department
    ON Employee.departmentId = Department.id

INNER JOIN top_salaries_by_dept
    ON top_salaries_by_dept.departmentId = Employee.departmentId
    AND top_salaries_by_dept.salary = Employee.salary
WHERE salary_rank <= 3
    ;

-- option 2
select
       department,
       employee,
       salary
from (
    select
       d.name as department,
       e.name as employee,
       salary,
       dense_rank() over (partition by d.id order by salary desc) as rn
    from employee e
        inner join department d
    on e.departmentid=d.id
    ) as ranking_table
where rn <= 3;
----------------------------------------------------------------------------------------------------------------------
/****** Advanced String Functions / Regex /Clause ******/
----------------------------------------------------------------------------------------------------------------------
-- Fix Names in a Table
SELECT
user_id,
UPPER(SUBSTRING(name, 1, 1)) || LOWER(SUBSTRING(name,2, LENGTH(name))) as name
-- not INITCAP(name) because solution wants only first letter upper
FROM Users
ORDER by user_id
;
----------------------------------------------------------------------------------------------------------------------
-- Patients With a Condition
SELECT
patient_id,
patient_name,
conditions
FROM Patients
WHERE  (UPPER(conditions) LIKE 'DIAB1%'
        OR UPPER(conditions) LIKE '% DIAB1%')
;
----------------------------------------------------------------------------------------------------------------------
-- Delete Duplicate Emails
DELETE FROM Person
USING (SELECT
    MIN(id) as min_id,
    email
FROM Person
GROUP BY email
) as min_rec
WHERE id != min_id
and person.email = min_rec.email;

-- option 2
delete from person
where id not in (
                select min(id) from person
                group by email
);
----------------------------------------------------------------------------------------------------------------------
-- Second Highest Salary (Medium)
SELECT
    MAX(salary) as SecondHighestSalary
FROM Employee
WHERE salary < (SELECT MAX(salary) as max_salary FROM Employee)
;
----------------------------------------------------------------------------------------------------------------------
-- Group Sold Products By The Date
SELECT
    sell_date,
    COUNT(DISTINCT product) as num_sold,
    STRING_AGG(DISTINCT product, ',') as products
FROM Activities
GROUP BY sell_date
;

----------------------------------------------------------------------------------------------------------------------
-- List the Products Ordered in a Period
SELECT
    product_name,
    SUM(unit) as unit
FROM Orders as o
INNER JOIN Products as p
    ON p.product_id = o.product_id

WHERE order_date >= '2020-02-01'
AND order_date < '2020-03-01'
GROUP BY product_name
HAVING SUM(unit) >= 100;

----------------------------------------------------------------------------------------------------------------------
-- Find Users With Valid E-Mails
SELECT
user_id,
"name",
mail
FROM Users
WHERE (SUBSTRING(mail,1,1) ~* '[a-z]') is true
AND (SUBSTRING(mail,1,POSITION('@leetcode.com' IN mail)-1) ~* '^[a-z0-9_.-]+$') is true
AND lower(mail) LIKE '%@leetcode.com'
;

-- optimal
SELECT *
FROM Users
WHERE mail ~ '^[A-Za-z][A-Za-z0-9._-]*@leetcode\.com$'
;
----------------------------------------------------------------------------------------------------------------------
-- COALESCE(NULLIF(,0),1)