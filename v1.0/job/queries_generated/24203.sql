WITH movie_roles AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS role_count,
        STRING_AGG(DISTINCT ct.kind, ', ') AS role_types
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.role_id = ct.id
    GROUP BY 
        ci.movie_id
),
aggregated_info AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mr.role_count, 0) AS total_roles,
        COALESCE(mr.role_types, 'No Roles Assigned') AS roles,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        MAX(mi.info) AS highest_rating,
        ARRAY_AGG(DISTINCT c.name) AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_roles mr ON mr.movie_id = t.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        t.id, mr.role_count, mr.role_types
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_roles,
        roles,
        keyword_count,
        highest_rating,
        company_names,
        ROW_NUMBER() OVER (ORDER BY total_roles DESC, keyword_count DESC, production_year DESC) AS rank
    FROM 
        aggregated_info
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_roles,
    rm.roles,
    rm.keyword_count,
    rm.highest_rating,
    rm.company_names,
    CASE 
        WHEN rm.highest_rating IS NULL THEN 'Rating Not Available'
        ELSE 'Rated: ' || rm.highest_rating 
    END AS rating_status,
    CASE 
        WHEN rm.rank <= 10 THEN 'Top 10 Ranked Movie'
        ELSE 'Not in Top 10'
    END AS top_status
FROM 
    ranked_movies rm
WHERE 
    rm.production_year >= 2000
    AND EXISTS (
        SELECT 1 
        FROM movie_title mt 
        WHERE mt.movie_id = rm.movie_id AND mt.title ILIKE '%Action%'
    )
ORDER BY 
    rm.rank;

This SQL query leverages various constructs such as Common Table Expressions (CTEs), window functions, outer joins, correlated subqueries, and complex CASE statements to explore the schema provided. The aim is to obtain a ranked list of movies based on their roles and keywords while considering additional attributes like rating and associated companies. The filtering includes specific conditions that target modern films with an action-related title.
