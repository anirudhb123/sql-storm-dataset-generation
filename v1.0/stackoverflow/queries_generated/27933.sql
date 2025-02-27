WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        STRING_AGG(t.TagName, ', ') AS Tags,
        p.CreationDate,
        p.ViewCount,
        P.ANSWERCOUNT,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY(STRING_TO_ARRAY(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(b.Class) AS TotalBadges,
        MAX(p.CreationDate) AS LatestPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.Reputation
),

PostInteractions AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        p.Id
)

SELECT 
    up.UserId,
    up.Reputation,
    up.PostCount,
    up.TotalBadges,
    up.LatestPostDate,
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    pi.VoteCount,
    pi.UpVotes,
    pi.DownVotes
FROM 
    UserReputation up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.PostId -- This might typically link back to User, using proper logic.
LEFT JOIN 
    PostInteractions pi ON pi.PostId = rp.PostId
WHERE 
    up.Reputation > 1000
    AND rp.UserPostRank <= 5
ORDER BY 
    up.Reputation DESC, rp.ViewCount DESC
LIMIT 100;
