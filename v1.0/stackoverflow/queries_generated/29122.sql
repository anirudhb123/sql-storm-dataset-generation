WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Questions
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Upvote and Downvote
    GROUP BY 
        u.Id, u.DisplayName
),

RecentChanges AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        pt.Name AS ChangeType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        ph.CreationDate > (CURRENT_TIMESTAMP - INTERVAL '30 days')
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ua.QuestionCount,
    ua.AcceptedAnswers,
    ua.UpvotesReceived,
    COUNT(DISTINCT rc.PostId) AS RecentChangesCount,
    STRING_AGG(DISTINCT rc.ChangeType || ': ' || rc.Comment, '; ' ORDER BY rc.CreationDate DESC) AS RecentChangeComments,
    COUNT(DISTINCT rp.PostId) AS RecentPostsCount,
    STRING_AGG(DISTINCT rp.Title, ', ' ORDER BY rp.CreationDate DESC) AS RecentPostTitles
FROM 
    Users u
LEFT JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.Rank <= 5 -- Latest 5 questions per user
LEFT JOIN 
    RecentChanges rc ON rp.PostId = rc.PostId
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    ua.QuestionCount DESC, ua.UpvotesReceived DESC
LIMIT 100;
