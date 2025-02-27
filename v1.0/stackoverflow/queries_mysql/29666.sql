
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.CreationDate,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        (SELECT p2.ViewCount FROM Posts p2 WHERE p2.Id = p.Id ORDER BY p2.ViewCount LIMIT 1 OFFSET (SELECT COUNT(*) FROM Posts p3 WHERE p3.ViewCount < p.ViewCount) / 2) AS MedianViews
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (NOW() - INTERVAL 30 DAY)
    GROUP BY 
        p.Id, p.CreationDate, p.Title
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS HistoryCount,
        GROUP_CONCAT(DISTINCT CASE WHEN pht.Name = 'Post Closed' THEN 'Closed' ELSE 'Edited' END SEPARATOR ', ') AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.CommentCount,
    pa.Upvotes,
    pa.Downvotes,
    pa.MedianViews,
    phd.HistoryCount,
    phd.ChangeTypes
FROM 
    TagStats ts
LEFT JOIN 
    PostActivity pa ON pa.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%', ts.TagName, '%'))
LEFT JOIN 
    PostHistoryDetails phd ON pa.PostId = phd.PostId
ORDER BY 
    ts.PostCount DESC, ts.TagName;
