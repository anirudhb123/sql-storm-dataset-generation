WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    us.DisplayName AS Author,
    rs.TotalUpVotes,
    rs.TotalDownVotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    p.Score AS PostScore,
    ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank,
    CASE 
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer
FROM 
    RankedPosts rp
JOIN 
    Users us ON rp.OwnerUserId = us.Id
LEFT JOIN 
    UserStats rs ON us.Id = rs.UserId
LEFT JOIN 
    PostComments pc ON rp.Id = pc.PostId
WHERE 
    rp.OwnerRank = 1
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 50;
