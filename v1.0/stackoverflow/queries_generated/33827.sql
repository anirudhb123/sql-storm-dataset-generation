WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only questions
),
PostVoteCount AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        pvc.UpVotes,
        pvc.DownVotes,
        (pvc.UpVotes - pvc.DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCount pvc ON rp.PostId = pvc.PostId
    WHERE 
        rp.PostRank = 1  -- Get the latest posts per user
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount,
        MAX(CreationDate) AS LastCommentDate
    FROM 
        Comments
    GROUP BY 
        PostId
),
FinalOutput AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        tp.UpVotes,
        tp.DownVotes,
        tp.NetVotes,
        CASE 
            WHEN pc.LastCommentDate IS NULL then 'No Comments'
            ELSE CONCAT('Last Commented on: ', TO_CHAR(pc.LastCommentDate, 'YYYY-MM-DD HH24:MI:SS'))
        END AS LastCommentInfo
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)

SELECT 
    FO.*, 
    CASE 
        WHEN FO.Score >= 10 THEN 'High Score'
        WHEN FO.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    CASE 
        WHEN UpVotes > DownVotes THEN 'Positive'
        WHEN UpVotes < DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    FinalOutput FO
ORDER BY 
    FO.Score DESC, FO.CreationDate DESC;
