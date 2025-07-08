
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CharCount AS (
    SELECT 
        t.id AS movie_id,
        SUM(LENGTH(t.title) - LENGTH(REPLACE(t.title, ' ', '')) + 1) AS space_count,
        COUNT(DISTINCT m.name) AS actor_count
    FROM 
        aka_title t
    INNER JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name m ON c.person_id = m.person_id
    GROUP BY 
        t.id
),
FilteredMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        CASE 
            WHEN r.rank_within_year <= 3 THEN 'Top 3 in Year'
            ELSE 'Other'
        END AS ranking_category,
        cc.space_count,
        cc.actor_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        CharCount cc ON r.movie_id = cc.movie_id
    WHERE 
        r.production_year > 2000
),
MovieDetails AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.ranking_category,
        COALESCE(f.space_count, 0) AS space_count,
        COALESCE(f.actor_count, 0) AS actor_count,
        CASE 
            WHEN COALESCE(f.space_count, 0) > 10 THEN 'Very Wordy'
            WHEN COALESCE(f.actor_count, 0) = 0 THEN 'No Cast'
            ELSE 'Standard'
        END AS description
    FROM 
        FilteredMovies f
)
SELECT 
    md.title,
    md.production_year,
    md.ranking_category,
    md.space_count,
    md.actor_count,
    md.description,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.ranking_category, md.space_count, md.actor_count, md.description, cn.name
ORDER BY 
    md.production_year DESC, md.ranking_category DESC, md.title
LIMIT 100;
