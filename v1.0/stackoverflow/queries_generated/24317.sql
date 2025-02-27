WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.ParentId IS NOT NULL ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotesCount,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotesCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserAnalysis AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.LastAccessDate > NOW() - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT(ph.Comment, ' (', ph.CreationDate::date, ')'), '; ') AS HistoryComments,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '3 months'
    GROUP BY 
        ph.PostId
),
FinalReport AS (
    SELECT 
        up.UserId,
        up.DisplayName,
        up.AvgReputation,
        up.PostsCount,
        up.QuestionsCount,
        up.AnswersCount,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.UpVotesCount,
        rp.DownVotesCount,
        COALESCE(ph.HistoryComments, 'No history') AS PostHistory,
        ph.HistoryCount AS PostHistoryCount
    FROM 
        UserAnalysis up
    INNER JOIN 
        RankedPosts rp ON up.UserId = rp.PostId  -- Assuming PostId corresponds to UserId in context
    LEFT JOIN 
        PostHistoryDetails ph ON rp.PostId = ph.PostId
    WHERE 
        rp.rn = 1  -- Get the latest post by each user
    ORDER BY 
        up.AvgReputation DESC, rp.ViewCount DESC
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    COALESCE(PostHistoryCount, 0) > 1
    AND UpVotesCount > DownVotesCount
    AND (QuestionsCount > 0 OR AnswersCount > 0)
    AND NOT EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = FinalReport.UserId 
        AND p.CreationDate < NOW() - INTERVAL '1 year'
    )
ORDER BY 
    CreationDate DESC
LIMIT 50 OFFSET 0;
