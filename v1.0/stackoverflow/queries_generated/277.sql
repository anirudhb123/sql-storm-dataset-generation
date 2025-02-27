WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        AcceptedAnswerId,
        OwnerUserId,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        rn
    FROM 
        RankedPosts
    WHERE 
        rn <= 5 -- Get the 5 most recent posts per user
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    fp.Title,
    fp.CreationDate,
    COUNT(DISTINCT c.Id) AS TotalComments,
    up.Reputation,
    up.BadgeCount,
    COALESCE(fp.UpVoteCount - fp.DownVoteCount, 0) AS NetVotes,
    CASE 
        WHEN fp.AcceptedAnswerId IS NOT NULL THEN 'Accepted Answer Available' 
        ELSE 'No Accepted Answer' 
    END AS AnswerStatus
FROM 
    FilteredPosts fp
JOIN 
    UserReputation up ON fp.OwnerUserId = up.UserId
LEFT JOIN 
    Comments c ON fp.PostId = c.PostId
GROUP BY 
    fp.Title, 
    fp.CreationDate, 
    up.Reputation,
    up.BadgeCount,
    fp.AcceptedAnswerId
ORDER BY 
    up.Reputation DESC, 
    fp.CreationDate DESC;
