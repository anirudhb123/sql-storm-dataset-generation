WITH StringProcessingBenchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ph.UserDisplayName AS LastEditorDisplayName,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS HasUpvote,
        MAX(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS HasDownvote,
        ph.CreationDate AS LastEditDate,
        ph.UserId AS LastEditorUserId,
        ph.Comment AS EditComment
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.CreationDate = (
            SELECT MAX(ph2.CreationDate) 
            FROM PostHistory ph2 
            WHERE ph2.PostId = p.Id
        )
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS t ON t IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, ph.UserDisplayName, ph.CreationDate, ph.UserId, ph.Comment
),
TagGroupOptions AS (
    SELECT
        UNNEST(TAGS_ARRAY) AS TagName
    FROM (
        SELECT STRING_TO_ARRAY(STRING_AGG(DISTINCT TRIM(TagList), ', '), ', ') AS TAGS_ARRAY
        FROM StringProcessingBenchmark
    ) AS TempTable
),
BenchmarkStats AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsageCount,
        STRING_AGG(DISTINCT DisplayName, ', ') AS UsersMentioned,
        COUNT(DISTINCT PostId) AS TotalPosts
    FROM 
        StringProcessingBenchmark
    JOIN 
        TagGroupOptions tgo ON tgo.TagName = ANY(STRING_TO_ARRAY(TagList, ', '))
    GROUP BY 
        TagName
)
SELECT 
    TagName, 
    TagUsageCount, 
    UsersMentioned, 
    TotalPosts, 
    ROW_NUMBER() OVER (ORDER BY TagUsageCount DESC) AS TagRanking
FROM 
    BenchmarkStats
ORDER BY 
    TagUsageCount DESC;
