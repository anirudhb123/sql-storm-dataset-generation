WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredRankedMovies AS (
    SELECT 
        title_id, 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5  -- Only the top 5 movies per production year
),
MovieDetails AS (
    SELECT 
        f.title_id,
        f.title,
        f.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        SUM(CASE 
            WHEN ci.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS noted_actors_count
    FROM 
        FilteredRankedMovies f
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (
            SELECT person_id 
            FROM cast_info 
            WHERE movie_id IN (SELECT movie_id FROM aka_title WHERE id = f.title_id)
        )
    LEFT JOIN 
        cast_info ci ON ci.movie_id IN (SELECT movie_id FROM aka_title WHERE id = f.title_id)
    GROUP BY 
        f.title_id, f.title, f.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        md.actor_names,
        md.noted_actors_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        MovieKeywords mk ON md.title_id = mk.movie_id
)
SELECT 
    title,
    production_year,
    actor_names,
    noted_actors_count,
    keywords
FROM 
    FinalOutput
WHERE 
    (noted_actors_count > 0 AND keywords != 'No Keywords')
    OR (noted_actors_count = 0 AND keywords = 'No Keywords')
ORDER BY 
    production_year DESC, noted_actors_count DESC, title;
