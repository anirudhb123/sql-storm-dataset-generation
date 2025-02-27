WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3), 0) AS DownVoteCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags
),
FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Location,
        u.Views,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
)
SELECT 
    fu.DisplayName,
    fu.Reputation,
    fu.Location,
    fu.Views,
    rp.Title,
    rp.Body,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rp.CommentCount,
    rp.UserPostRank
FROM 
    FilteredUsers fu
JOIN 
    RankedPosts rp ON fu.UserId = rp.OwnerUserId
WHERE 
    fu.UserRank <= 100 -- Top 100 users based on reputation
    AND rp.UserPostRank <= 5 -- Top 5 posts per user
ORDER BY 
    fu.Reputation DESC, rp.UpVoteCount DESC;
