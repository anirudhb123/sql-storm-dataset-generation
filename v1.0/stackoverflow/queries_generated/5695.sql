WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(STRING_AGG(t.TagName, ','), ',')) AS TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Posts p
    JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(p.Tags, '><')::int[])
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        t.TagName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        PopularTags
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.CommentCount,
    r.VoteCount,
    tt.TagName AS PopularTag,
    tt.PostCount
FROM 
    RankedPosts r
JOIN 
    TopTags tt ON r.Rank <= 10
ORDER BY 
    r.Score DESC, r.ViewCount DESC;
