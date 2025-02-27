WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > '2022-01-01'
),

PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),

TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.ViewCount,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes,
        r.Rank
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostVoteCounts pvc ON r.PostId = pvc.PostId
    WHERE 
        r.Rank <= 10
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (1, 4, 10) THEN 1 END) AS TitleChanges,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (2, 5) THEN 1 END) AS BodyChanges,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (6) THEN 1 END) AS TagChanges
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    tp.Title AS Post_Title,
    tp.ViewCount AS Total_Views,
    tp.UpVotes AS Total_UpVotes,
    tp.DownVotes AS Total_DownVotes,
    COALESCE(ps.HistoryCount, 0) AS History_Record_Count,
    COALESCE(ps.TitleChanges, 0) AS Title_Change_Count,
    COALESCE(ps.BodyChanges, 0) AS Body_Change_Count,
    COALESCE(ps.TagChanges, 0) AS Tag_Change_Count,
    CASE 
        WHEN tp.UpVotes > tp.DownVotes THEN 'More Upvotes' 
        WHEN tp.UpVotes < tp.DownVotes THEN 'More Downvotes' 
        ELSE 'Equal Votes' 
    END AS Vote_Comparison,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS Comment_Count,
    COALESCE(
        (SELECT MAX(CreationDate) 
         FROM Comments c 
         WHERE c.PostId = tp.PostId 
           AND c.CreationDate < CURRENT_TIMESTAMP - INTERVAL '1 year'
        ), 
        'No Comments in Last Year'
    ) AS Last_Comment_Date

FROM 
    TopPosts tp
LEFT JOIN 
    PostHistoryStats ps ON tp.PostId = ps.PostId
ORDER BY 
    tp.ViewCount DESC;
