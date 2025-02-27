WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        u.DisplayName AS Author,
        COALESCE(ans.Score, 0) AS AnswerScore,
        COALESCE(vote.VoteCount, 0) AS VoteCount,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(vote.VoteCount, 0)) OVER (PARTITION BY p.Id) AS TotalVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AcceptanceStatus,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RecentPostsByType
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT 
            ParentId, 
            SUM(Score) AS Score 
         FROM 
            Posts 
         WHERE 
            PostTypeId = 2 
         GROUP BY 
            ParentId) ans ON p.Id = ans.ParentId
    LEFT JOIN 
        (SELECT 
            PostId, 
            COUNT(*) AS VoteCount 
         FROM 
            Votes 
         GROUP BY 
            PostId) vote ON p.Id = vote.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, ans.Score, vote.VoteCount
)
SELECT 
    ur.UserId,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeCount,
    pd.PostId,
    pd.Title,
    pd.Author,
    pd.AnswerScore,
    pd.VoteCount,
    pd.CommentCount,
    pd.TotalVotes,
    pd.AcceptanceStatus,
    CASE 
        WHEN pd.RecentPostsByType <= 5 THEN 'Recent'
        ELSE 'Older'
    END AS PostRecency
FROM 
    UserReputation ur
JOIN 
    PostDetails pd ON ur.UserId = pd.Author
WHERE 
    ur.Reputation > 1000
    AND (pd.PostTypeId IN (1, 2) OR pd.AcceptanceStatus = 'Accepted')
ORDER BY 
    ur.Reputation DESC, pd.TotalVotes DESC
LIMIT 10 OFFSET 0;

-- Find posts linked to each other and categorize them by link type and user reputation.
WITH RelatedPosts AS (
    SELECT 
        pl.PostId AS OriginalPostId,
        pl.RelatedPostId,
        lt.Name AS LinkTypeName,
        u.Reputation AS RelatedUserReputation
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    JOIN 
        Posts op ON pl.PostId = op.Id
    LEFT JOIN 
        Users u ON op.OwnerUserId = u.Id
)
SELECT 
    rp.OriginalPostId,
    rp.RelatedPostId,
    COUNT(*) AS LinkCount,
    MAX(rp.RelatedUserReputation) AS MaxReputation
FROM 
    RelatedPosts rp
GROUP BY 
    rp.OriginalPostId, rp.RelatedPostId
HAVING 
    MAX(rp.RelatedUserReputation) > 500
ORDER BY 
    LinkCount DESC, MaxReputation DESC;
