WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,  -- Assuming VoteTypeId = 2 corresponds to UpMod
        SUM(v.VoteTypeId = 3) AS DownVotes, -- Assuming VoteTypeId = 3 corresponds to DownMod
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only considering Questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  -- Get the top posts for each user
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,  -- Aggregate badge names for users
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    ub.BadgeNames,
    ub.BadgeCount
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.PostId IN (SELECT ParentId FROM Posts WHERE Id = tp.PostId)
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    tp.AnswerCount > 0  -- Only include posts with answers
ORDER BY 
    tp.UpVotes DESC
LIMIT 100;  -- Limiting the result to top 100 posts
