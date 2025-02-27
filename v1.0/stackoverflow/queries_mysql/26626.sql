
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        REPLACE(REPLACE(p.Tags, '><', ','), '<', '') AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(TagsArray, ',', numbers.n), ',', -1) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        PostStats
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
         SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(TagsArray) - CHAR_LENGTH(REPLACE(TagsArray, ',', '')) >= numbers.n - 1
    GROUP BY 
        Tag
),
PopularTags AS (
    SELECT 
        Tag,
        PostCount,
        @RowNum := @RowNum + 1 AS TagRank
    FROM 
        TagStats, (SELECT @RowNum := 0) r
    WHERE 
        PostCount > 1 
    ORDER BY 
        PostCount DESC
),
TagBenchmark AS (
    SELECT 
        pt.Tag,
        pt.PostCount,
        ps.OwnerDisplayName,
        ps.Title,
        ps.CommentCount,
        ps.VoteCount,
        ps.CreationDate
    FROM 
        PopularTags pt
    JOIN 
        PostStats ps ON FIND_IN_SET(pt.Tag, ps.TagsArray)
)
SELECT 
    Tag,
    COUNT(*) AS TotalPosts,
    AVG(CommentCount) AS AvgCommentCount,
    AVG(VoteCount) AS AvgVoteCount,
    MIN(CreationDate) AS FirstPostDate,
    MAX(CreationDate) AS LastPostDate
FROM 
    TagBenchmark
GROUP BY 
    Tag
ORDER BY 
    AvgCommentCount DESC, 
    AvgVoteCount DESC
LIMIT 10;
