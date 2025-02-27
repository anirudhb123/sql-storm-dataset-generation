
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(a.Id, -1) AS AcceptedAnswerId,
        COALESCE(a.Title, 'No Accepted Answer') AS AcceptedAnswerTitle,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT pt.Name ORDER BY pt.Name ASC SEPARATOR ', ') AS PostTypeName,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        (SELECT Id, TRIM(TRAILING '>' FROM TRIM(LEADING '<' FROM Tags)) AS TagsTrimmed,
                SUBSTRING_INDEX(SUBSTRING_INDEX(TagsTrimmed, '><', numbers.n), '><', -1) AS TagName
         FROM Posts
         INNER JOIN (SELECT 1 as n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                      UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) 
                      - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) t 
    ON p.Id = t.Id
    GROUP BY 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Tags, 
        u.DisplayName, 
        a.Id, 
        a.Title
),
AggregatePostStats AS (
    SELECT 
        OwnerDisplayName,
        COUNT(PostId) AS TotalPosts,
        SUM(ViewCount) AS TotalViews,
        SUM(CommentCount) AS TotalComments,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        PostDetails
    GROUP BY 
        OwnerDisplayName
    ORDER BY 
        TotalPosts DESC
)
SELECT 
    aps.OwnerDisplayName,
    aps.TotalPosts,
    aps.TotalViews,
    aps.TotalComments,
    aps.AvgViewCount
FROM 
    AggregatePostStats aps
WHERE 
    aps.TotalPosts > 5
ORDER BY 
    aps.TotalViews DESC;
