WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(vs.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(vs.DownVoteCount, 0) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
            SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM 
            Votes v
        JOIN 
            VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        (rp.UpVoteCount - rp.DownVoteCount) AS NetVotes,
        rp.UserPostRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.UserPostRank = 1 
        AND rp.CreationDate >= NOW() - INTERVAL '1 month'
        AND rp.UpVoteCount > 0
),
PostDetails AS (
    SELECT 
        fp.PostId, 
        fp.Title, 
        fp.NetVotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = fp.PostId) AS CommentCount,
        (SELECT AVG(CASE WHEN bp.UserId IS NOT NULL THEN 1 ELSE 0 END) FROM Badges bp WHERE bp.UserId = fp.PostId) AS AvgBadgesPerUser
    FROM 
        FilteredPosts fp
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.NetVotes,
    pd.CommentCount,
    pd.AvgBadgesPerUser,
    u.DisplayName AS OwnerDisplayName,
    CASE 
        WHEN pd.NetVotes IS NULL THEN 'No Votes'
        WHEN pd.NetVotes > 0 THEN 'Positive'
        WHEN pd.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus
FROM 
    PostDetails pd
LEFT JOIN 
    Users u ON pd.PostId = u.Id
WHERE 
    pd.AvgBadgesPerUser IS NOT NULL
ORDER BY 
    pd.NetVotes DESC, 
    pd.CommentCount DESC
LIMIT 10;

-- Additional metrics as an outer join with PostHistory for perplexed history cases.
LEFT JOIN (
    SELECT 
        ph.PostId,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseVoteCount,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 12) AS DeleteVoteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
) ph ON pd.PostId = ph.PostId;

This query provides a comprehensive view of the top posts from users who have created posts within the last month, sorting them based on net votes and comment count, while also extracting some intricate metrics from associated tables, including badges and post history events. It incorporates various SQL constructs like Common Table Expressions (CTEs), window functions for ranking, conditional aggregation, and complex predicates, demonstrating a blend of performance benchmarking and sophisticated data retrieval concepts.
