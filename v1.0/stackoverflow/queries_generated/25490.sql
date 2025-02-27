WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT t.TagName) AS TagCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS TagName ON TagName IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = TagName
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
), 

PopularUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        u.Id
    HAVING
        COUNT(DISTINCT p.Id) > 5
    ORDER BY 
        TotalViews DESC
    LIMIT 10
), 

PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        p.Title,
        p.Body,
        ph.Comment,
        p.AcceptedAnswerId,
        ph.UserDisplayName
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Considering Post Closed and Post Reopened history
),

AggregatePostData AS (
    SELECT
        pt.PostId,
        pt.TagCount,
        pu.DisplayName AS PopularUser,
        COUNT(DISTINCT ph.PostId) AS HistoryCount
    FROM 
        PostTagCounts pt
    JOIN 
        PopularUsers pu ON pu.QuestionCount > 5
    LEFT JOIN 
        PostHistoryDetails ph ON pt.PostId = ph.PostId
    GROUP BY 
        pt.PostId, pu.DisplayName, pt.TagCount
)

SELECT 
    apd.PostId,
    apd.TagCount,
    apd.PopularUser,
    apd.HistoryCount
FROM 
    AggregatePostData apd
ORDER BY 
    apd.TagCount DESC, 
    apd.HistoryCount DESC;
