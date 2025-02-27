WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cp.id AS company_id,
        cp.name AS company_name
    FROM 
        ranked_movies rm
    JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    JOIN 
        company_name cp ON mc.company_id = cp.id
    WHERE 
        cp.country_code = 'USA'
),
actor_movies AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.id IN (SELECT id FROM name WHERE gender = 'F')  -- Female actors
),
movie_details AS (
    SELECT 
        fm.movie_id,
        fm.title,
        ARRAY_AGG(DISTINCT am.actor_name ORDER BY am.nr_order) AS cast,
        ARRAY_AGG(DISTINCT fm.company_name) AS companies
    FROM 
        filtered_movies fm
    LEFT JOIN 
        actor_movies am ON fm.movie_id = am.movie_id
    GROUP BY 
        fm.movie_id, fm.title
),
final_selection AS (
    SELECT 
        md.movie_id,
        md.title,
        md.cast,
        md.companies,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.movie_id) AS info_count
    FROM 
        movie_details md
    WHERE 
        md.title ILIKE '%love%'  -- Movies with 'love' in the title
    ORDER BY 
        md.title, info_count DESC
)
SELECT 
    fs.movie_id,
    fs.title,
    fs.cast,
    fs.companies,
    fs.info_count
FROM 
    final_selection fs
LIMIT 
    100;

This SQL query benchmarks string processing by aggregating information about movies produced in the USA with female actors and filtering titles that contain the word "love". It ranks the titles by year and allows for further exploratory joins involving movie companies. The output includes a curated list of movie titles, their cast, associated companies, and the count of related movie information, limited to the top 100 results.
