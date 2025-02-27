WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate >= current_date - interval '1 year' -- Posts created in the last year
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- Top 5 posts per user
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpVoteCount,
        tp.DownVoteCount,
        COALESCE(phe.EditCount, 0) AS EditCount,
        phe.LastEditDate
    FROM 
        TopPosts tp
    LEFT JOIN PostHistoryStats phe ON tp.PostId = phe.PostId
)
SELECT 
    f.PostId,
    f.Title,
    f.Score,
    f.CreationDate,
    f.OwnerDisplayName,
    f.CommentCount,
    f.UpVoteCount,
    f.DownVoteCount,
    f.EditCount,
    f.LastEditDate,
    CASE 
        WHEN f.LastEditDate IS NULL THEN 'Not Edited'
        ELSE CONCAT('Edited on ', TO_CHAR(f.LastEditDate, 'YYYY-MM-DD HH24:MI:SS'))
    END AS EditStatus
FROM 
    FinalResults f
ORDER BY 
    f.Score DESC, f.CommentCount DESC;
