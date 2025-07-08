
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
QualifiedMovies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN rm.cast_count > 5 THEN 'Large Cast'
            WHEN rm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    qm.title,
    qm.production_year,
    qm.cast_size,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cc.note, 'No notes available') AS actor_notes,
    CASE 
        WHEN qm.production_year < 2000 THEN 'Classic'
        WHEN qm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    QualifiedMovies qm
LEFT JOIN 
    movie_info mi ON qm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
LEFT JOIN 
    MovieKeywords mk ON qm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON qm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    company_name c ON c.imdb_id = (SELECT imdb_id FROM company_name WHERE name = 'Warner Bros' LIMIT 1)
LEFT JOIN 
    movie_companies mc ON qm.movie_id = mc.movie_id AND mc.company_id = c.id
LEFT JOIN 
    (SELECT 
         movie_id, note 
     FROM 
         cast_info 
     WHERE 
         role_id IN (SELECT role_id FROM role_type WHERE role LIKE '%supporting%')
     GROUP BY movie_id, note
    ) AS cc ON cc.movie_id = qm.movie_id
ORDER BY 
    qm.production_year DESC, 
    qm.title ASC
LIMIT 50;
