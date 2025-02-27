WITH Recents AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS AuthorName,
        u.Reputation AS AuthorReputation,
        COALESCE(ac.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) as TotalComments,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) as TotalUpVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts ac ON p.Id = ac.AcceptedAnswerId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days' 
        AND p.PostTypeId = 1  -- Only looking at questions
),
TagStats AS (
    SELECT 
        tg.TagName,
        COUNT(p.Id) AS TotalQuestions,
        SUM(COALESCE(v.UpVotes, 0)) AS TotalVotes
    FROM 
        Tags tg
    JOIN 
        Posts p ON p.Tags LIKE '%' || tg.TagName || '%'
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS UpVotes
        FROM 
            Votes v 
        WHERE 
            v.VoteTypeId = 2 -- Only upvotes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    GROUP BY 
        tg.TagName
    ORDER BY 
        TotalVotes DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstEditDate,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) -- Edit Title, Edit Body, Edit Tags, Suggested Edit Applied
    GROUP BY 
        ph.PostId
)

SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.CreationDate,
    r.Tags,
    r.AuthorName,
    r.AuthorReputation,
    r.AcceptedAnswerId,
    r.TotalComments,
    r.TotalUpVotes,
    t.TagName,
    ts.TotalQuestions,
    ts.TotalVotes,
    phs.FirstEditDate,
    phs.EditCount
FROM 
    Recents r
LEFT JOIN 
    TagStats ts ON r.Tags LIKE '%' || ts.TagName || '%'
LEFT JOIN 
    PostHistoryStats phs ON r.PostId = phs.PostId
ORDER BY 
    r.TotalUpVotes DESC, r.CreationDate DESC;
