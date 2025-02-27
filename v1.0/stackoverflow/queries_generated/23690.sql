WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPostsVoted
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        v.UserId
),
PostDetails AS (
    SELECT 
        p.PostId,
        p.Title,
        rp.ViewCount,
        COALESCE(u.Reputation, 0) AS UserReputation,
        CASE
            WHEN MAX(b.Class) IS NULL THEN 'No Badges'
            ELSE STRING_AGG(b.Name, ', ')
        END AS UserBadges,
        COALESCE(up.UpVotes, 0) - COALESCE(dn.DownVotes, 0) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.PostId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        UserVoteStats up ON u.Id = up.UserId
    LEFT JOIN 
        UserVoteStats dn ON u.Id = dn.UserId
    WHERE 
        rp.PostRank <= 10
    GROUP BY 
        p.PostId, p.Title, rp.ViewCount, u.Reputation
),
FinalSelection AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.UserReputation,
        pd.UserBadges,
        pd.NetVotes,
        COALESCE(ph.Comment, 'No historical comment') AS HistoryComments,
        COUNT(c.Id) AS CommentCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistory ph ON pd.PostId = ph.PostId AND ph.CreationDate >= CURRENT_DATE - INTERVAL '6 months'
    LEFT JOIN 
        Comments c ON pd.PostId = c.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.ViewCount, pd.UserReputation, pd.UserBadges, pd.NetVotes, ph.Comment
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.ViewCount,
    fs.UserReputation,
    fs.UserBadges,
    fs.NetVotes,
    fs.HistoryComments,
    fs.CommentCount,
    CASE 
        WHEN fs.ViewCount IS NULL THEN 'No views yet'
        WHEN fs.ViewCount > 100 THEN 'Popular'
        WHEN fs.ViewCount BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Needs Exposure'
    END AS PopularityStatus
FROM 
    FinalSelection fs
WHERE 
    fs.UserReputation > 100
ORDER BY 
    fs.ViewCount DESC, fs.NetVotes DESC;
