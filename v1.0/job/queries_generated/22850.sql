WITH Recursive_Cast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        c.note,
        COALESCE(CAST(ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS VARCHAR), 'No Order') AS order_sequence
    FROM 
        cast_info c
    WHERE 
        c.note IS NOT NULL
    UNION ALL
    SELECT 
        cc.movie_id,
        cc.person_id,
        cc.note,
        COALESCE(CAST(ROW_NUMBER() OVER (PARTITION BY cc.movie_id ORDER BY cc.nr_order) AS VARCHAR), 'No Order') AS order_sequence
    FROM 
        cast_info cc
    JOIN 
        Recursive_Cast rc ON rc.movie_id = cc.movie_id
    WHERE 
        cc.note IS NOT NULL AND cc.person_id != rc.person_id
),
Latest_Movies AS (
    SELECT 
        DISTINCT ON (t.title)
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        SUM(mk.keyword IS NOT NULL) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    ORDER BY 
        t.title, t.production_year DESC
),
Top_Cast AS (
    SELECT 
        l.movie_id,
        COUNT(l.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names,
        MAX(l.note) AS notes
    FROM 
        Recursive_Cast l
    LEFT JOIN 
        aka_name n ON n.person_id = l.person_id
    GROUP BY 
        l.movie_id
)
SELECT 
    lm.title,
    lm.production_year,
    lm.keyword_count,
    tc.total_cast,
    tc.cast_names,
    COALESCE(tc.notes, 'No Notes') AS notes,
    CASE 
        WHEN lm.production_year IS NULL THEN 'No Year'
        ELSE 
            CASE 
                WHEN lm.production_year < 2010 THEN 'Old Movie'
                ELSE 
                    'Recent Movie'
            END 
    END AS movie_age_category
FROM 
    Latest_Movies lm
LEFT JOIN 
    Top_Cast tc ON tc.movie_id = lm.movie_id
WHERE 
    (lm.keyword_count > 5 OR lm.production_year IS NULL)
ORDER BY 
    lm.production_year DESC NULLS LAST, 
    tc.total_cast DESC;
