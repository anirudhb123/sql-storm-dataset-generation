
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
        LISTAGG(DISTINCT pt.Name, ', ') AS PostTypeName,
        LISTAGG(DISTINCT t.TagName, ', ') AS TagsList
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
        (SELECT Id, TRIM(value) AS TagName 
         FROM Posts, LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LENGTH(Tags) - 2), '><')))) t 
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
