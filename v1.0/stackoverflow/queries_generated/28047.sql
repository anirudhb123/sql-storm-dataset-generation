WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.TagName) AS TagCount
    FROM 
        Posts p
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) AS CloseVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COUNT(DISTINCT c.Id) AS CommentsMade,
        COUNT(DISTINCT b.Id) AS BadgesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.Location,
    ua.PostsCreated,
    ua.CommentsMade,
    ua.BadgesReceived,
    pt.TagCount,
    pv.UpVoteCount,
    pv.DownVoteCount,
    pv.CloseVoteCount
FROM 
    Users u
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    PostTagCounts pt ON pt.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN 
    PostVoteCounts pv ON pv.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    u.Reputation > 1000  -- Only include users with significant reputation
ORDER BY 
    u.Reputation DESC
LIMIT 10;
