WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.PostTypeId,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostCTE r ON p.ParentId = r.PostId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    u.Reputation,
    u.CreationDate AS UserSince,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(CASE WHEN rp.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN rp.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
    MAX(rp.CreationDate) AS LastActivity,
    AVG(rp.AnswerCount) AS AvgAnswersPerQuestion,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    Users u
LEFT JOIN 
    RecursivePostCTE rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    LATERAL (SELECT UNNEST(STRING_TO_ARRAY(Posts.Tags, ',')) AS TagName FROM Posts WHERE Id = rp.PostId) t ON TRUE
WHERE 
    u.Reputation > 1000 
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, u.CreationDate
HAVING 
    COALESCE(SUM(CASE WHEN rp.PostTypeId = 2 THEN 1 ELSE 0 END), 0) > 0  -- At least one answer for the user
ORDER BY 
    u.Reputation DESC
LIMIT 10;

-- Comparing users with their badge counts
SELECT 
    u.Id AS UserId,
    u.DisplayName AS UserName,
    COUNT(b.Id) AS BadgeCount,
    SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
    SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
    SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    BadgeCount DESC
FETCH FIRST 5 ROWS ONLY;

-- Checking the post history for a particular user with relevant comments that have been made
SELECT 
    p.Id AS PostId,
    p.Title,
    ph.CreationDate AS HistoryDate,
    ph.UserDisplayName AS EditorName,
    ph.Text AS ChangeDetails,
    ph.Comment AS Comment
FROM 
    PostHistory ph
INNER JOIN 
    Posts p ON ph.PostId = p.Id
WHERE 
    ph.UserId = @UserId
ORDER BY 
    ph.CreationDate DESC;
