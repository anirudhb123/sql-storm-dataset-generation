WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        string_agg(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT mci.company_id) AS production_companies,
        COUNT(DISTINCT mk.keyword) AS keywords
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    JOIN 
        movie_companies mci ON t.id = mci.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
AvgCastCount AS (
    SELECT 
        AVG(word_count(cast_names)) AS avg_cast_count
    FROM (
        SELECT 
            string_agg(DISTINCT c.name, ', ') AS cast_names
        FROM 
            title t
        JOIN 
            cast_info ci ON t.id = ci.movie_id
        JOIN 
            aka_name c ON ci.person_id = c.person_id
        WHERE 
            t.production_year BETWEEN 2000 AND 2023
        GROUP BY 
            t.id
    ) AS cast_counts
),
KeywordCount AS (
    SELECT 
        movie_name,
        COUNT(DISTINCT keyword_id) AS keyword_count
    FROM (
        SELECT 
            t.title AS movie_name,
            mk.keyword_id
        FROM 
            title t
        JOIN 
            movie_keyword mk ON t.id = mk.movie_id
        WHERE 
            t.production_year BETWEEN 2000 AND 2023
    ) AS movie_keywords
    GROUP BY 
        movie_name
)

SELECT 
    md.movie_title, 
    md.production_year, 
    md.cast_names, 
    md.production_companies, 
    kc.keyword_count,
    ac.avg_cast_count
FROM 
    MovieDetails md
JOIN 
    KeywordCount kc ON md.movie_title = kc.movie_name
CROSS JOIN 
    AvgCastCount ac
ORDER BY 
    md.production_year DESC, 
    md.production_companies DESC;


This SQL query leverages common table expressions (CTEs) to gather various metrics regarding movies produced between 2000 and 2023, such as the average number of cast members per film and the count of keywords associated with each movie. The query provides a holistic view of string processing capabilities by aggregating names, counting unique keywords, and calculating average cast sizes.
