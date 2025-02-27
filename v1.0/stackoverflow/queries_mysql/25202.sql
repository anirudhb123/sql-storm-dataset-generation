
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
        AND p.PostTypeId = 1 
        AND p.Body IS NOT NULL
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts 
    INNER JOIN 
        (SELECT a.N + b.N * 10 AS n
        FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    GROUP BY 
        TagName
),
MaxTagStats AS (
    SELECT 
        TagName,
        PostCount,
        @Rank := @Rank + 1 AS Rank
    FROM 
        TagStats, (SELECT @Rank := 0) r
    ORDER BY 
        PostCount DESC
),
PostRankings AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.OwnerDisplayName,
        fp.CommentCount,
        fp.UpVoteCount,
        COALESCE(mt.Rank, 0) AS TagRank
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        MaxTagStats mt ON fp.Tags LIKE CONCAT('%', mt.TagName, '%')
)
SELECT 
    pr.PostId,
    pr.Title,
    pr.OwnerDisplayName,
    pr.CommentCount,
    pr.UpVoteCount,
    pr.TagRank
FROM 
    PostRankings pr
WHERE 
    pr.TagRank <= 5
ORDER BY 
    pr.UpVoteCount DESC, pr.CommentCount DESC;
