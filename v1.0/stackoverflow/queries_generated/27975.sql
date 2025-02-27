WITH TagStatistics AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN PostTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM 
        Posts
    CROSS JOIN 
        (SELECT 
            TRIM(UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')))::varchar) AS TagName
         FROM 
            Posts 
         WHERE 
            Tags IS NOT NULL) AS TagList
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryStatistics AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS IsClosed,
        COUNT(ph.Id) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 25 THEN 1 ELSE 0 END) AS IsTweeted
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.ClosedPostCount,
    ue.DisplayName AS UserDisplayName,
    ue.TotalPosts,
    ue.TotalComments,
    ue.TotalBounty,
    phs.EditCount AS TotalEdits,
    phs.IsClosed,
    phs.IsTweeted
FROM 
    TagStatistics ts
JOIN 
    Posts p ON ts.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
JOIN 
    UserEngagement ue ON p.OwnerUserId = ue.UserId
JOIN 
    PostHistoryStatistics phs ON p.Id = phs.PostId
WHERE 
    ts.PostCount > 10
ORDER BY 
    ts.PostCount DESC, ue.TotalBounty DESC
LIMIT 50;
