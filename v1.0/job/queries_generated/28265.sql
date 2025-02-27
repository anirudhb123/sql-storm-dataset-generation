WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rt.aka_id,
        rt.aka_name,
        rt.movie_title,
        rt.production_year,
        t.kind_id,
        k.keyword AS movie_keyword
    FROM 
        RankedTitles rt
    JOIN 
        title t ON rt.title_id = t.id
    LEFT JOIN 
        movie_keyword mk ON rt.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    md.aka_name,
    md.movie_title,
    md.production_year,
    kt.kind AS movie_kind,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM 
    MovieDetails md
JOIN 
    kind_type kt ON md.kind_id = kt.id
WHERE 
    md.rank = 1 
GROUP BY 
    md.aka_name, md.movie_title, md.production_year, kt.kind
ORDER BY 
    md.production_year DESC, md.aka_name;

This query first ranks titles associated with each person in the `aka_name` table based on the production year of the movies. It filters results to get the most recent title for each person and enriches the data with their corresponding movie kind and keywords, using `STRING_AGG` to concatenate multiple keywords into a single string for better readability. The output is then sorted by production year and name for structured results.
