-- Table Creation

create table orders (
order_id int not null,
order_date date not null,
order_time time not null,
primary key(order_id)
);

create table order_details (
order_details_id int not null primary key,
order_id int,
pizza_id text,
quantity int
);

-- ANALYSIS

-- Retrieve the total number of orders placed.
select count(*)  total_number_of_orders from orders;

-- Calculate the total revenue generated from pizza sales.
select round(sum(price*quantity),2) from order_details od
join orders o on od.order_id = o.order_id
join pizzas p on od.pizza_id = p.pizza_id;

-- Identify the highest-priced pizza.
select * from pizzas
order by price desc
limit 1;

-- Identify the most common pizza size ordered.
select size, count(size) from order_details od
join orders o on od.order_id = o.order_id
join pizzas p on od.pizza_id = p.pizza_id
group by size
order by count(size) desc;

-- List the top 5 most ordered pizza types along with their quantities.
select name, sum(quantity) quantity from pizzas p
join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by name
order by quantity desc
limit 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered.
select category, sum(quantity) quantity from pizzas p
join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by category
order by quantity desc;

-- Determine the distribution of orders by hour of the day.
select hour(order_time) hour,count(order_id) order_count from orders
group by hour(order_time);

-- Join relevant tables to find the category-wise distribution of pizzas.
select category, count(name) from pizza_types
group by category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
select round(avg(quantity),0) from
(select o.order_date, sum(od.quantity) quantity from orders o
join order_details od on od.order_id = o.order_id
group by order_date) as order_quantity;

-- Determine the top 3 most ordered pizza types based on revenue.
select name, sum(quantity * price) revenue from pizzas p
join pizza_types pt on p.pizza_type_id = pt.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by name
order by revenue desc
limit 3;

-- Calculate the percentage contribution of each pizza type to total revenue.
select category, sum(quantity * price)/ (	select sum(price*quantity) from order_details od
											join orders o on od.order_id = o.order_id
											join pizzas p on od.pizza_id = p.pizza_id ) * 100 as revenue
from pizza_types pt
join pizzas p on pt.pizza_type_id = p.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by category
order by revenue desc;
-- using with clause or CTE
WITH TotalRevenue AS (
    SELECT SUM(price * quantity) AS total_revenue
    FROM order_details od
    JOIN orders o ON od.order_id = o.order_id
    JOIN pizzas p ON od.pizza_id = p.pizza_id
)
SELECT category, 
       SUM(quantity * price) / (SELECT total_revenue FROM TotalRevenue) * 100 AS revenue
FROM pizza_types pt
JOIN pizzas p ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od ON p.pizza_id = od.pizza_id
GROUP BY category
ORDER BY revenue DESC;

-- Analyze the cumulative revenue generated over time.
select order_date, 
sum(revenue) over(order by order_date) as cum_revenue
from
(select o.order_date, sum(p.price * od.quantity) revenue from  order_details od
join pizzas p on od.pizza_id = p.pizza_id
join orders o on o.order_id = od.order_id
group by o.order_date) as sales;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
select name, revenue from
(select category, name, revenue, rank() over(partition by category order by revenue desc) as rn
from
(select pt.category, pt.name, sum(od.quantity * p.price) revenue from pizza_types pt
join pizzas p on pt.pizza_type_id = p.pizza_type_id
join order_details od on p.pizza_id = od.pizza_id
group by pt.category, pt.name) a) b
where rn <= 3;