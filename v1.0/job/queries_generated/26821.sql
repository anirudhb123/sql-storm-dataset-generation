WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS ranking
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.movie_id = mc.movie_id
    JOIN 
        complete_cast cc ON a.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        name n ON an.person_id = n.imdb_id
    GROUP BY 
        a.title, a.production_year
),
FilteredTitles AS (
    SELECT 
        title,
        production_year,
        company_count,
        cast_names
    FROM 
        RankedTitles
    WHERE 
        ranking <= 5
)
SELECT 
    f.projection_year,
    STRING_AGG(f.title || ' (' || f.company_count || ' companies, Cast: ' || f.cast_names || ')', '; ') AS title_details
FROM 
    FilteredTitles f
GROUP BY 
    f.production_year
ORDER BY 
    f.production_year DESC;

This SQL query produces a ranked list of top 5 movies per production year based on the number of companies involved in making the film. It concatenates details of each title including its name, number of associated companies, and the names of the cast members.
