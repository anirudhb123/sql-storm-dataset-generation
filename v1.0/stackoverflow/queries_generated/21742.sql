WITH UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(h.Comment, 'No comments') AS LastComment,
        COALESCE(h.CreationDate, '1970-01-01'::timestamp) AS LastHistoryDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId AND h.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = p.Id)
    WHERE 
        p.ViewCount > 1000
),
TagDetails AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount,
        DENSE_RANK() OVER (ORDER BY COUNT(p.Id) DESC) AS TagRank
    FROM 
        Tags t 
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%' )
    GROUP BY 
        t.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ps.Title AS PostTitle,
    ps.CreationDate AS PostCreationDate,
    ps.LastComment,
    ps.ActivityRank,
    td.TagName,
    td.PostCount,
    us.Rank AS UserRank
FROM 
    UserScoreCTE us
JOIN 
    PostDetails ps ON us.UserId = ps.OwnerUserId
JOIN 
    TagDetails td ON td.PostCount > 5
WHERE 
    (us.UpVotes - us.DownVotes) > 10 
    AND ps.LastHistoryDate >= NOW() - INTERVAL '30 days'
    AND (td.TagName IS NOT NULL OR td.TagId IS NULL)
ORDER BY 
    UserRank, ActivityRank, PostCreationDate DESC;
