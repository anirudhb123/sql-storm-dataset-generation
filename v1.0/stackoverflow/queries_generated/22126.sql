WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankByType,
        COALESCE(p.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2::smallint) AS UpVotes,  -- Upvote Sum
        SUM(v.VoteTypeId = 3::smallint) AS DownVotes  -- Downvote Sum
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AcceptedAnswerId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        HasAcceptedAnswer,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankByType <= 5  -- Top 5 Posts per Type
),

UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
EnhancedPostInfo AS (
    SELECT 
        tp.*,
        u.DisplayName AS PostOwner,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        TopPosts tp
    JOIN 
        Users u ON tp.PostId = u.Id  -- Hypothetical join, assuming PostId represents User
    LEFT JOIN 
        UserBadgeCounts ub ON u.Id = ub.UserId
)

SELECT 
    epi.PostId,
    epi.Title,
    epi.CreationDate,
    epi.Score,
    epi.ViewCount,
    CASE 
        WHEN epi.HasAcceptedAnswer = 0 THEN 'No Accepted Answer'
        ELSE 'Has Accepted Answer'
    END AS AnswerStatus,
    epi.CommentCount,
    epi.UpVotes,
    epi.DownVotes,
    epi.PostOwner,
    COALESCE(epi.BadgeCount, 0) AS BadgeCount,
    COALESCE(epi.BadgeNames, 'None') AS BadgeNames,
    CONCAT('Post Score: ', epi.Score, ' with ', epi.ViewCount, ' views.') AS PostScoreDetail
FROM 
    EnhancedPostInfo epi
WHERE 
    epi.Score > (SELECT AVG(Score) FROM Posts)  -- Only posts above average score
ORDER BY 
    epi.Score DESC, epi.ViewCount DESC
LIMIT 50;

-- Checking for NULL logic using condition on User Id
SELECT 
    u.Id, 
    COALESCE(u.DisplayName, 'Anonymous') AS SafeDisplayName, 
    COUNT(DISTINCT p.Id) AS PostCount
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id
HAVING 
    COUNT(DISTINCT p.Id) IS NULL OR COUNT(DISTINCT p.Id) > 0;  -- Users with no posts or more than 0

-- Checking OPTIONAL and COALESCE with STRING_AGG
SELECT 
    u.Id,
    u.DisplayName AS UserDisplayName,
    COALESCE(STRING_AGG(b.BadgeName, ', '), 'No Badges') AS UserBadges
FROM 
    Users u
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    u.Id 
HAVING 
    COUNT(b.Id) > 2;  -- Users with more than 2 badges
