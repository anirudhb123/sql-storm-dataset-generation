WITH RECURSIVE UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = (SELECT unnest(string_to_array(p.Tags, '<>'))::int) -- Assuming Tags are encoded in <tag1><tag2>
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.PostId) > 10  -- More than 10 usages
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserDisplayName
),
CombinedStats AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.PostCount,
        ups.QuestionCount,
        ups.AnswerCount,
        ups.TotalBounty,
        pt.TagName,
        COALESCE(rph.LastActionDate, 'No Activity') AS LastActivity
    FROM 
        UserPostStats ups
    LEFT JOIN 
        PopularTags pt ON ups.PostCount > 0
    LEFT JOIN 
        RecentPostHistory rph ON ups.UserId = rph.UserId
)

SELECT 
    cs.DisplayName,
    cs.PostCount,
    cs.QuestionCount,
    cs.AnswerCount,
    cs.TotalBounty,
    cs.TagName,
    cs.LastActivity
FROM 
    CombinedStats cs
WHERE 
    cs.PostCount > 5
    AND cs.TotalBounty > 0
ORDER BY 
    cs.PostCount DESC,
    cs.TotalBounty DESC;

-- This query calculates user statistics including the number of posts, questions, and answers.
-- It also aggregates popular tags based on usage, recent post history for each user,
-- and provides a final output of users with significant activity and awards.
