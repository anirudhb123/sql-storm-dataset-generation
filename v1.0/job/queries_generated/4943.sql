WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        m.title,
        m.actor_count,
        ROW_NUMBER() OVER (ORDER BY m.actor_count DESC) AS rank
    FROM 
        MovieStats m
    WHERE 
        m.actor_count > 5
)
SELECT 
    tm.title,
    tm.actor_count,
    CASE 
        WHEN tm.rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS category
FROM 
    TopMovies tm
WHERE 
    EXISTS (
        SELECT 1
        FROM aka_title at
        WHERE at.title = tm.title AND at.production_year = (
            SELECT MAX(production_year)
            FROM aka_title
            WHERE title = tm.title
        )
    )
ORDER BY 
    tm.actor_count DESC, 
    tm.title;
