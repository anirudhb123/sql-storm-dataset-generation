WITH RecentActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.AnswerCount,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year' AND 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        p.Id
),
TopActivePosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.LastActivityDate,
        r.AnswerCount,
        r.ViewCount,
        r.UpVotes,
        r.DownVotes
    FROM 
        RecentActivePosts r
    WHERE 
        r.RowNum <= 10
),
PostDetails AS (
    SELECT 
        p.Title AS PostTitle,
        u.DisplayName AS OwnerName,
        COALESCE(CHAR_LENGTH(c.Text), 0) AS CommentLength,
        COUNT(c.Id) AS CommentCount
    FROM 
        TopActivePosts t
    JOIN 
        Posts p ON t.PostId = p.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Title, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
)

SELECT 
    pd.PostTitle,
    pd.OwnerName,
    pd.CommentLength,
    pd.CommentCount,
    p.UpVotes,
    p.DownVotes,
    COALESCE(phs.EditCount, 0) AS TotalEdits,
    phs.LastEditDate
FROM 
    PostDetails pd
JOIN 
    TopActivePosts p ON pd.PostTitle = p.Title
LEFT JOIN 
    PostHistoryStats phs ON p.PostId = phs.PostId
WHERE 
    pd.CommentCount > 0
ORDER BY 
    p.ViewCount DESC, p.LastActivityDate DESC;
