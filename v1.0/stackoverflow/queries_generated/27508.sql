WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(v.UpVoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(v.DownVoteCount, 0)) AS TotalDownVotes,
        SUM(COALESCE(c.CommentCount, 0)) AS TotalComments
    FROM
        Tags t
    LEFT JOIN (
        SELECT 
            UNNEST(string_to_array(substring(Tags, 2, length(Tags) - 2), '> <'))::varchar) AS Tag,
            p.Id,
            p.AnswerCount,
            COALESCE(c.CommentCount, 0) AS CommentCount
        FROM 
            Posts p
        LEFT JOIN (
            SELECT 
                PostId, COUNT(*) AS CommentCount
            FROM 
                Comments
            GROUP BY 
                PostId
        ) c ON p.Id = c.PostId
        WHERE 
            p.PostTypeId = 1
    ) AS post_tags ON post_tags.Tag = t.TagName
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS UpVoteCount, 
                   (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = v.PostId AND v2.VoteTypeId = 3) AS DownVoteCount
        FROM 
            Votes v
        WHERE 
            v.VoteTypeId = 2
        GROUP BY 
            PostId
    ) v ON v.PostId = post_tags.Id
    GROUP BY 
        t.TagName
),
PostHistoryStats AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentEditIndex
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 10, 11) -- Focus on title/body edits and close/reopen actions
)
SELECT
    ts.TagName,
    ts.PostCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.TotalComments,
    COUNT(DISTINCT ph.PostId) AS EditsCount,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.PostId END) AS ClosureCount,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN ph.PostId END) AS ContentEditCount,
    STRING_AGG(DISTINCT ph.UserId::VARCHAR, ', ') AS EditorUserIds,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    TagStats ts
LEFT JOIN 
    PostHistoryStats ph ON ph.PostId IN (SELECT DISTINCT p.Id FROM Posts p WHERE p.Tags LIKE '%' || ts.TagName || '%')
GROUP BY 
    ts.TagName
ORDER BY 
    ts.PostCount DESC, ts.TotalUpVotes DESC;
