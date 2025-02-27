WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ca ON at.id = ca.movie_id
    GROUP BY 
        at.title, at.production_year
),
TopTitles AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedTitles
    WHERE 
        year_rank <= 5
),
KeywordStats AS (
    SELECT 
        at.id AS movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        at.id, k.keyword
),
MovieDetails AS (
    SELECT 
        tt.title,
        tt.production_year,
        SUM(ks.keyword_count) AS total_keywords
    FROM 
        TopTitles tt
    LEFT JOIN 
        KeywordStats ks ON tt.title = ks.movie_id
    GROUP BY 
        tt.title, tt.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.total_keywords,
    CASE 
        WHEN md.total_keywords > 10 THEN 'Highly Tagged'
        WHEN md.total_keywords BETWEEN 5 AND 10 THEN 'Moderately Tagged'
        ELSE 'Sparsely Tagged'
    END AS tag_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.total_keywords DESC;

This query benchmarks string processing by gathering statistics on movies produced from 2000 to 2023, focusing on actor counts and keyword associations for the top 5 most casted movies per year. The results are further categorized based on the total number of keywords associated, providing valuable insights on movie metadata richness.
