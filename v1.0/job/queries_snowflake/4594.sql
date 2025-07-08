
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS rank_within_year,
        COUNT(kw.id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank_within_year,
        rm.keyword_count,
        CASE 
            WHEN rm.production_year = 2020 THEN 'Recent Release'
            WHEN rm.production_year < 2000 THEN 'Classic'
            ELSE 'Contemporary'
        END AS era
    FROM 
        ranked_movies rm
    WHERE 
        rm.keyword_count > 2
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_member_count,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.era,
    cd.cast_member_count,
    cd.cast_names
FROM 
    filtered_movies fm
LEFT JOIN 
    cast_details cd ON fm.movie_id = cd.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.rank_within_year;
