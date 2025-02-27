WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id = ANY (STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>'))::int[]
    GROUP BY 
        p.Id
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT v.PostId) AS PostsVotedOn
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ph.UserId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN cr.Name
            ELSE NULL
        END AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    ups.TotalUpVotes,
    ups.TotalDownVotes,
    ups.PostsVotedOn,
    phd.PostHistoryTypeId,
    phd.CreationDate AS HistoryDate,
    phd.CloseReason
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteStats ups ON rp.PostId = ups.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    (rp.UserRank = 1 AND rp.Score > 0)
    OR (phd.CloseReason IS NOT NULL AND phd.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days')
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
