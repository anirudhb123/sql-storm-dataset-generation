WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
PostInteractions AS (
    SELECT 
        p.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        Comments c ON tp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON tp.PostId = v.PostId
    GROUP BY 
        p.PostId
)

SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.AnswerCount,
    pi.CommentCount,
    pi.UpVoteCount,
    pi.DownVoteCount,
    CASE 
        WHEN pi.UpVoteCount IS NOT NULL AND pi.DownVoteCount IS NOT NULL THEN 
            pi.UpVoteCount - pi.DownVoteCount 
        ELSE 
            0 
    END AS NetVotes,
    COUNT(DISTINCT b.Id) AS TotalBadges
FROM 
    TopPosts tp
LEFT JOIN 
    PostInteractions pi ON tp.PostId = pi.PostId
LEFT JOIN 
    Badges b ON b.UserId IN (
        SELECT DISTINCT OwnerUserId 
        FROM Posts 
        WHERE PostId = tp.PostId
    )
GROUP BY 
    tp.PostId, pi.CommentCount, pi.UpVoteCount, pi.DownVoteCount
ORDER BY 
    NetVotes DESC, tp.Score DESC;
