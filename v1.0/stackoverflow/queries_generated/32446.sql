WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(ut.UpVotes, 0) AS TotalUpVotes,
        COALESCE(ut.DownVotes, 0) AS TotalDownVotes,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            SUM(CASE WHEN vt.Id = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN vt.Id = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes v
        JOIN 
            VoteTypes vt ON vt.Id = v.VoteTypeId
        GROUP BY 
            OwnerUserId
    ) ut ON ut.OwnerUserId = p.OwnerUserId
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
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    pc.CommentCount,
    pc.LastCommentDate,
    pha.HistoryTypes,
    pha.HistoryCount,
    pt.TagName,
    pt.TagCount,
    CASE 
        WHEN rp.TotalUpVotes IS NULL AND rp.TotalDownVotes IS NULL THEN 'No votes'
        WHEN rp.TotalUpVotes > rp.TotalDownVotes THEN 'More upvotes'
        ELSE 'More downvotes'
    END AS VoteStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostComments pc ON pc.PostId = rp.PostId
LEFT JOIN 
    PostHistoryAggregated pha ON pha.PostId = rp.PostId
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(STRING_TO_ARRAY(rp.Tags, ', '))
WHERE 
    rp.RowNum = 1
ORDER BY 
    rp.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
