WITH RecursiveUserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.BountyAmount) AS TotalBounty,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
), RecentPostHistory AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        p.Title,
        p.Tags,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS LatestRevision
    FROM PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
), TagSummary AS (
    SELECT
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.QuestionCount,
    u.AnswerCount,
    COALESCE(r.LastRevision, 'No recent edits') AS LastRevision,
    COALESCE(ts.TagCount, 0) AS AssociatedTagsCount,
    COALESCE(b.TotalBounty, 0) AS TotalBountyAmount
FROM RecursiveUserEngagement u
LEFT JOIN (
    SELECT 
        PostId, 
        STRING_AGG(CONCAT(UserDisplayName, ' on ', CreationDate::date), '; ') AS LastRevision
    FROM RecentPostHistory
    WHERE LatestRevision = 1
    GROUP BY PostId
) r ON u.UserId = r.UserId
LEFT JOIN (
    SELECT 
        TagName, 
        COUNT(*) AS TagCount
    FROM TagSummary
    GROUP BY TagName
) ts ON ts.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, ',')) FROM Posts p WHERE p.OwnerUserId = u.UserId)
LEFT JOIN (
    SELECT 
        UserId, 
        SUM(BountyAmount) AS TotalBounty
    FROM Votes
    WHERE VoteTypeId IN (8, 9) -- Bounty start and close
    GROUP BY UserId
) b ON b.UserId = u.UserId
WHERE u.Reputation >= 1000
ORDER BY u.UserRank;
