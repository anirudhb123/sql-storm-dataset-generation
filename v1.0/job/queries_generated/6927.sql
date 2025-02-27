WITH RecursiveCTE AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        c.movie_id,
        t.title AS movie_title,
        c.nr_order,
        p.id AS person_id,
        p.name AS person_name,
        cc.kind AS cast_kind,
        ci.note AS cast_note
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        name p ON a.person_id = p.imdb_id
    LEFT JOIN 
        comp_cast_type cc ON c.person_role_id = cc.id
    LEFT JOIN 
        movie_info mi ON c.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        t.production_year >= 2000
    UNION ALL
    SELECT 
        r.aka_id,
        r.aka_name,
        r.movie_id,
        r.movie_title,
        r.nr_order,
        r.person_id,
        r.person_name,
        r.cast_kind,
        r.cast_note
    FROM 
        RecursiveCTE r
    JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%Action%' 
)
SELECT 
    aka_id,
    aka_name,
    movie_id,
    movie_title,
    person_name,
    nr_order,
    cast_kind,
    cast_note
FROM 
    RecursiveCTE
ORDER BY 
    movie_id, nr_order;
