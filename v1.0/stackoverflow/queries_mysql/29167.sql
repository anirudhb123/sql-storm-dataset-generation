
WITH TagUsage AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag,
        Id AS PostId
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 + 1 AS n
         FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
    ON 
        n.n <= 1 + (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', ''))) 
    WHERE 
        PostTypeId = 1 
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS TagCount
    FROM 
        TagUsage
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS Rank
    FROM 
        TagStats
),
PostInteraction AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 6 THEN 1 ELSE 0 END), 0) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
FinalStats AS (
    SELECT 
        tt.Tag,
        pi.PostId,
        p.Title,
        pi.CommentCount,
        pi.UpvoteCount,
        pi.DownvoteCount,
        pi.CloseVoteCount
    FROM 
        PostInteraction pi
    JOIN 
        Posts p ON pi.PostId = p.Id
    JOIN 
        TopTags tt ON tt.Rank <= 10 
    WHERE 
        FIND_IN_SET(tt.Tag, TRIM(BOTH '>' FROM REPLACE(REPLACE(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><', ','), ',', '><')))) > 0
)
SELECT 
    fs.Tag,
    COUNT(fs.PostId) AS PostCount,
    SUM(fs.CommentCount) AS TotalComments,
    SUM(fs.UpvoteCount) AS TotalUpvotes,
    SUM(fs.DownvoteCount) AS TotalDownvotes,
    SUM(fs.CloseVoteCount) AS TotalCloseVotes
FROM 
    FinalStats fs
GROUP BY 
    fs.Tag
ORDER BY 
    PostCount DESC, 
    TotalUpvotes DESC;
