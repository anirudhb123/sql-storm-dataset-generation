WITH RecentPostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 DAY'
    GROUP BY 
        p.Id
), UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(rpa.CommentCount, 0)) AS TotalComments,
        SUM(rpa.UpVotes) AS TotalUpVotes,
        SUM(rpa.DownVotes) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        RecentPostActivity rpa ON u.Id = rpa.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalComments,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    COALESCE(ROUND(ups.TotalUpVotes::numeric / NULLIF(ups.TotalComments, 0) * 100, 2), 0) AS UpvotePercentage,
    CASE 
        WHEN ups.TotalUpVotes > ups.TotalDownVotes THEN 'Positive Engagement'
        WHEN ups.TotalUpVotes < ups.TotalDownVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus
FROM 
    UserPostSummary ups
WHERE 
    ups.TotalComments > 0
ORDER BY 
    ups.TotalComments DESC
LIMIT 10;
