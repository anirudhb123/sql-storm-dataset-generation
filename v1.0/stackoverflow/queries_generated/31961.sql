WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.Reputation,
        p.Score,
        COUNT(pc.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    WHERE 
        p.PostTypeId = 1 -- Only Questions
    GROUP BY 
        p.Id, u.Reputation, p.Score, p.Title, p.CreationDate
),
LatestPostHistory AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS MaxCreationDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) -- Post close and reopen
    GROUP BY 
        ph.PostId
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Reputation,
        rp.Score,
        rp.CommentCount,
        COALESCE(pvs.UpVoteCount, 0) AS UpVotes,
        COALESCE(pvs.DownVoteCount, 0) AS DownVotes,
        CASE 
            WHEN lph.MaxCreationDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        rp.UserPostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        LatestPostHistory lph ON rp.PostId = lph.PostId
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostId = pvs.PostId
    WHERE 
        rp.Rank <= 10 -- Limit to the top 10 most recent posts per user
)
SELECT 
    *,
    CONCAT(Title, ' (', UpVotes - DownVotes, ' net votes)') AS VoteSummary
FROM 
    FinalResults
WHERE 
    Reputation > 100 -- Filter for users with a high reputation
ORDER BY 
    CreationDate DESC;
