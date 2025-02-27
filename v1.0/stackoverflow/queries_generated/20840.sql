WITH User_Reputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        Location,
        ROW_NUMBER() OVER (PARTITION BY Location ORDER BY Reputation DESC) AS RankByReputation
    FROM Users
    WHERE Reputation IS NOT NULL
),
Post_Statistics AS (
    SELECT 
        p.Id AS PostId,
        p.AcceptedAnswerId,
        p.OwnerUserId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(MAX(v.BountyAmount), 0) AS TotalBounty,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN LATERAL (
        SELECT 
            unnest(string_to_array(p.Tags, '><')) AS TagName
    ) AS t ON TRUE
    GROUP BY p.Id, p.AcceptedAnswerId, p.OwnerUserId, p.PostTypeId
),
Closed_Posts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName,
        ph.Comment AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS CloseRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
),
Ranked_Users AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.Location,
        ur.RankByReputation,
        ps.PostId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.TotalBounty,
        ps.Tags
    FROM 
        User_Reputation ur
    JOIN 
        Post_Statistics ps ON ur.UserId = ps.OwnerUserId
    WHERE 
        ur.RankByReputation <= 3
),
Final_Output AS (
    SELECT 
        ru.UserId,
        ru.Reputation,
        COALESCE(cp.CloseDate, 'No Close Record') AS CloseDate,
        COALESCE(cp.CloseReason, 'N/A') AS CloseReason,
        ru.PostId,
        ru.CommentCount,
        ru.UpVoteCount,
        ru.DownVoteCount,
        ru.TotalBounty,
        ru.Tags
    FROM 
        Ranked_Users ru
    LEFT JOIN Closed_Posts cp ON ru.PostId = cp.PostId AND cp.CloseRank = 1
)
SELECT 
    UserId,
    Reputation,
    CloseDate,
    CloseReason,
    PostId,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    TotalBounty,
    Tags
FROM 
    Final_Output
WHERE
    (Reputation > 1000 AND CloseDate IS NOT NULL) OR
    (Reputation <= 1000 AND CloseReason IS NOT NULL)
ORDER BY 
    Reputation DESC, CloseDate DESC NULLS LAST;
