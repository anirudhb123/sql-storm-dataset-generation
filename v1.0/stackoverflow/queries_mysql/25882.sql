
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    CROSS JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
        UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 
        UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 
        UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) n
    WHERE 
        p.PostTypeId = 1 AND CHAR_LENGTH(p.Tags) > 2
),
RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COUNT(v.Id) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT t.Tag) AS TagCount,
        @rank := @rank + 1 AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostTags t ON p.Id = t.PostId
    CROSS JOIN (SELECT @rank := 0) r
    GROUP BY 
        p.Id, p.Title, p.ViewCount
    ORDER BY 
        p.ViewCount DESC, VoteCount DESC
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.VoteCount,
        rp.CommentCount,
        rp.TagCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10 
)
SELECT 
    t.Tag,
    COUNT(*) AS NumberOfPosts,
    SUM(tr.ViewCount) AS TotalViewCount,
    SUM(tr.VoteCount) AS TotalVotes,
    SUM(tr.CommentCount) AS TotalComments
FROM 
    TopRankedPosts tr
JOIN 
    PostTags t ON tr.PostId = t.PostId
GROUP BY 
    t.Tag
ORDER BY 
    NumberOfPosts DESC, TotalViewCount DESC;
