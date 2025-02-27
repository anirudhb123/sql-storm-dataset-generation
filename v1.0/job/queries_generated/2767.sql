WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(mci.note, 'No company linked') AS company_note
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_info_idx mii ON mi.id = mii.movie_id
    LEFT JOIN 
        movie_info mi2 ON mii.movie_id = mi2.movie_id 
    LEFT JOIN 
        movie_info_idx mii2 ON mi2.id = mii2.movie_id 
    LEFT JOIN 
        movie_link ml ON tm.movie_id = ml.movie_id
    LEFT JOIN 
        link_type lt ON ml.link_type_id = lt.id
    LEFT JOIN 
        movie_link ml2 ON tm.movie_id = ml2.linked_movie_id
    LEFT JOIN 
        title t2 ON ml2.linked_movie_id = t2.id
    LEFT JOIN 
        movie_info mci ON tm.movie_id = mci.movie_id
    WHERE 
        tm.production_year IS NOT NULL
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, mci.note
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_names,
    md.keywords,
    COALESCE(md.company_note, 'No company note available') AS company_note,
    CASE WHEN md.keywords IS NOT NULL THEN 'Has keywords' ELSE 'No keywords' END AS keyword_status,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
